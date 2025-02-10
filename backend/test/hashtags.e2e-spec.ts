import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('HashtagsController (e2e)', () => {
    let app: INestApplication;
    let authToken: string;

    beforeAll(async () => {
        const moduleFixture: TestingModule = await Test.createTestingModule({
            imports: [AppModule],
        }).compile();

        app = moduleFixture.createNestApplication();
        await app.init();

        // Step 1: Create an admin user & login
        const adminLoginResponse = await request(app.getHttpServer())
            .post('/auth/create-login')
            .send({
                address: '0x1234567890abcdef1234567890abcdef12345678', // Use a valid test address
                username: 'admin',
                email: 'admin@example.com'
            });

        authToken = adminLoginResponse.body.token;
    });

    it('should create a new hashtag (Admin Only)', async () => {
        const response = await request(app.getHttpServer())
            .post('/hashtags')
            .set('Authorization', `Bearer ${authToken}`)
            .send({ name: 'NestJS' });

        expect(response.status).toBe(201);
        expect(response.body.name).toBe('NestJS');
    });

    it('should fetch all hashtags', async () => {
        const response = await request(app.getHttpServer()).get('/hashtags');
        expect(response.status).toBe(200);
        expect(Array.isArray(response.body)).toBeTruthy();
    });

    afterAll(async () => {
        await app.close();
    });
});
