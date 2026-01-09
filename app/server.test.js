const request = require('supertest');
const app = require('./server');

describe('Application Tests', () => {
  afterAll((done) => {
    // Close the server after all tests
    done();
  });

  test('GET / should return application info', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('message');
    expect(response.body).toHaveProperty('version');
  });

  test('GET /health should return health status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
    expect(response.body).toHaveProperty('timestamp');
  });
});
