import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert';

const PROJECT_ID = 'demo-timerin';
const BASE_URL = `http://127.0.0.1:8080/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const COMMIT_URL = `${BASE_URL}:commit`;
const EMULATOR_CLEAR_URL = `http://127.0.0.1:8080/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

/**
 * Membuat mock JWT token untuk emulator Firebase Authentication.
 */
function createMockJwt(uid, email) {
  const header = Buffer.from(
    JSON.stringify({ alg: 'none', typ: 'JWT' }),
  ).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({
      sub: uid,
      user_id: uid,
      email: email || `${uid}@timerin.app`,
      aud: PROJECT_ID,
      iss: `https://securetoken.google.com/${PROJECT_ID}`,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      auth_time: Math.floor(Date.now() / 1000),
    }),
  ).toString('base64url');
  return `${header}.${payload}.`;
}

/**
 * Request dengan hak akses admin (bypass rules) untuk seeding state data pengujian.
 */
async function adminRequest(path, options = {}) {
  const headers = {
    'Authorization': 'Bearer owner',
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  return fetch(`${BASE_URL}${path}`, { ...options, headers });
}

/**
 * Request dengan kredensial pengguna terautentikasi.
 */
async function userRequest(uid, path, options = {}) {
  const token = createMockJwt(uid);
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  return fetch(`${BASE_URL}${path}`, { ...options, headers });
}

/**
 * Request publik tanpa otentikasi.
 */
async function publicRequest(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  return fetch(`${BASE_URL}${path}`, { ...options, headers });
}

/**
 * Membersihkan seluruh dokumen emulator sebelum setiap pengujian.
 */
async function clearDatabase() {
  await fetch(EMULATOR_CLEAR_URL, { method: 'DELETE' });
}

describe('Firestore Security Rules Tests (T-013, NFR-005, TECH §6)', () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  // -------------------------------------------------------------
  // 1. users/{uid} READ RULES
  // -------------------------------------------------------------
  describe('users/{uid} - Hak Baca (Read)', () => {
    it('mengizinkan pengguna membaca dokumen miliknya sendiri', async () => {
      // Seed data user alice lewat admin
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
            displayName: { stringValue: 'Alice' },
          },
        }),
      });

      const res = await userRequest('alice', '/users/alice');
      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.fields.email.stringValue, 'alice@timerin.app');
    });

    it('menolak pengguna lain membaca dokumen pengguna berbeda (403 Forbidden)', async () => {
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
          },
        }),
      });

      // Bob mencoba membaca dokumen alice
      const res = await userRequest('bob', '/users/alice');
      assert.strictEqual(res.status, 403);
    });

    it('menolak pembacaan tanpa login (unauthenticated) ke users/{uid}', async () => {
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
          },
        }),
      });

      const res = await publicRequest('/users/alice');
      assert.strictEqual(res.status, 403);
    });
  });

  // -------------------------------------------------------------
  // 2. users/{uid} CREATE RULES
  // -------------------------------------------------------------
  describe('users/{uid} - Pembuatan Dokumen Awal (Create)', () => {
    it('mengizinkan pembuatan dokumen awal yang valid dengan serverTimestamp', async () => {
      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  trialStartedAt: { nullValue: null },
                  subscriptionEndsAt: { nullValue: null },
                },
              },
              currentDocument: { exists: false },
            },
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'createdAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 200);
    });

    it('menolak pembuatan dokumen jika subscriptionEndsAt diisi (anti-bypass langganan)', async () => {
      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  trialStartedAt: { nullValue: null },
                  subscriptionEndsAt: { timestampValue: '2027-01-01T00:00:00Z' },
                },
              },
              currentDocument: { exists: false },
            },
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'createdAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak pembuatan dokumen jika trialStartedAt diisi saat create', async () => {
      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  trialStartedAt: { timestampValue: '2026-10-01T00:00:00Z' },
                  subscriptionEndsAt: { nullValue: null },
                },
              },
              currentDocument: { exists: false },
            },
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'createdAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak pembuatan dokumen jika field createdAt bukan serverTimestamp', async () => {
      const aliceToken = createMockJwt('alice');
      // Kirim createdAt dengan nilai manual/palsu
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  createdAt: { timestampValue: '2020-01-01T00:00:00Z' },
                  trialStartedAt: { nullValue: null },
                  subscriptionEndsAt: { nullValue: null },
                },
              },
              currentDocument: { exists: false },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak pembuatan dokumen jika memiliki field ilegal (misal isAdmin)', async () => {
      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  isAdmin: { booleanValue: true },
                  trialStartedAt: { nullValue: null },
                  subscriptionEndsAt: { nullValue: null },
                },
              },
              currentDocument: { exists: false },
            },
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'createdAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak pembuatan dokumen untuk UID pengguna lain (Bob create Alice)', async () => {
      const bobToken = createMockJwt('bob');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${bobToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'alice@timerin.app' },
                  displayName: { stringValue: 'Alice' },
                  trialStartedAt: { nullValue: null },
                  subscriptionEndsAt: { nullValue: null },
                },
              },
              currentDocument: { exists: false },
            },
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'createdAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });
  });

  // -------------------------------------------------------------
  // 3. users/{uid} UPDATE RULES
  // -------------------------------------------------------------
  describe('users/{uid} - Pembaruan Dokumen (Update)', () => {
    async function seedInitialAlice() {
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
            displayName: { stringValue: 'Alice' },
            createdAt: { timestampValue: '2026-10-07T12:00:00Z' },
            trialStartedAt: { nullValue: null },
            subscriptionEndsAt: { nullValue: null },
            lastSeenAt: { timestampValue: '2026-10-07T12:00:00Z' },
            deleteRequestedAt: { nullValue: null },
          },
        }),
      });
    }

    it('mengizinkan pembaruan lastSeenAt dengan serverTimestamp', async () => {
      await seedInitialAlice();

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'lastSeenAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 200);
    });

    it('mengizinkan aktivasi trial pertama kali dengan serverTimestamp saat trialStartedAt == null', async () => {
      await seedInitialAlice();

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'trialStartedAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                  {
                    fieldPath: 'lastSeenAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 200);
    });

    it('menolak aktivasi trial ganda / kedua kali jika trialStartedAt sudah ada (anti-reset trial)', async () => {
      // Seed user yang sudah pernah memulai trial
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
            displayName: { stringValue: 'Alice' },
            createdAt: { timestampValue: '2026-10-06T12:00:00Z' },
            trialStartedAt: { timestampValue: '2026-10-06T12:00:00Z' },
            subscriptionEndsAt: { nullValue: null },
            lastSeenAt: { timestampValue: '2026-10-06T12:00:00Z' },
          },
        }),
      });

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'trialStartedAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      // Harus DITOLAK (403 Forbidden)
      assert.strictEqual(res.status, 403);
    });

    it('menolak pengguna memperbarui subscriptionEndsAt (hanya developer/console)', async () => {
      await seedInitialAlice();

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  subscriptionEndsAt: { timestampValue: '2027-01-01T00:00:00Z' },
                },
              },
              updateMask: {
                fieldPaths: ['subscriptionEndsAt'],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak pembaruan field terproteksi seperti email atau createdAt', async () => {
      await seedInitialAlice();

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              update: {
                name: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fields: {
                  email: { stringValue: 'hacked@timerin.app' },
                },
              },
              updateMask: {
                fieldPaths: ['email'],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('mengizinkan pengajuan hapus akun (deleteRequestedAt == request.time)', async () => {
      await seedInitialAlice();

      const aliceToken = createMockJwt('alice');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${aliceToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'deleteRequestedAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 200);
    });

    it('menolak pengguna lain memperbarui dokumen pengguna (Bob update Alice)', async () => {
      await seedInitialAlice();

      const bobToken = createMockJwt('bob');
      const res = await fetch(COMMIT_URL, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${bobToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          writes: [
            {
              transform: {
                document: `projects/${PROJECT_ID}/databases/(default)/documents/users/alice`,
                fieldTransforms: [
                  {
                    fieldPath: 'lastSeenAt',
                    setToServerValue: 'REQUEST_TIME',
                  },
                ],
              },
            },
          ],
        }),
      });

      assert.strictEqual(res.status, 403);
    });
  });

  // -------------------------------------------------------------
  // 4. users/{uid} DELETE RULES
  // -------------------------------------------------------------
  describe('users/{uid} - Penghapusan Dokumen (Delete)', () => {
    it('menolak penghapusan dokumen oleh pengguna (allow delete: if false;)', async () => {
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
          },
        }),
      });

      const res = await userRequest('alice', '/users/alice', {
        method: 'DELETE',
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak penghapusan dokumen oleh siapapun tanpa otentikasi', async () => {
      await adminRequest('/users/alice', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            email: { stringValue: 'alice@timerin.app' },
          },
        }),
      });

      const res = await publicRequest('/users/alice', {
        method: 'DELETE',
      });

      assert.strictEqual(res.status, 403);
    });
  });

  // -------------------------------------------------------------
  // 5. config/app RULES
  // -------------------------------------------------------------
  describe('config/app - Konfigurasi Publik', () => {
    it('mengizinkan pembacaan publik tanpa login (unauthenticated)', async () => {
      await adminRequest('/config/app', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            minVersionCode: { integerValue: '1' },
            latestVersionCode: { integerValue: '2' },
          },
        }),
      });

      const res = await publicRequest('/config/app');
      assert.strictEqual(res.status, 200);
      const data = await res.json();
      assert.strictEqual(data.fields.latestVersionCode.integerValue, '2');
    });

    it('mengizinkan pembacaan oleh pengguna terautentikasi', async () => {
      await adminRequest('/config/app', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            latestVersionCode: { integerValue: '2' },
          },
        }),
      });

      const res = await userRequest('alice', '/config/app');
      assert.strictEqual(res.status, 200);
    });

    it('menolak penulisan / pembaruan config/app oleh pengguna terautentikasi (403 Forbidden)', async () => {
      const res = await userRequest('alice', '/config/app', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            latestVersionCode: { integerValue: '999' },
          },
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak penulisan / pembaruan config/app tanpa otentikasi (403 Forbidden)', async () => {
      const res = await publicRequest('/config/app', {
        method: 'PATCH',
        body: JSON.stringify({
          fields: {
            latestVersionCode: { integerValue: '999' },
          },
        }),
      });

      assert.strictEqual(res.status, 403);
    });

    it('menolak penghapusan config/app', async () => {
      const res = await userRequest('alice', '/config/app', {
        method: 'DELETE',
      });

      assert.strictEqual(res.status, 403);
    });
  });
});
