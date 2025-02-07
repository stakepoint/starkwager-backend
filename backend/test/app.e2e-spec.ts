import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';

describe('AppController (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let jwtService: JwtService;
  let authToken: string;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    prisma = app.get(PrismaService);
    jwtService = app.get(JwtService);

    await app.init();

    // Create a test user
    const testUser = await prisma.user.create({
      data: {
        address: 'test-address',
        email: 'test@example.com',
        username: 'testuser',
      },
    });

    // Generate JWT token for the test user
    authToken = jwtService.sign({ id: testUser.id, address: testUser.address });
  });

  afterEach(async () => {
    // Clean up the test user
    await prisma.user.deleteMany({
      where: {
        address: 'test-address',
      },
    });

    await app.close();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  it('/users/update (PATCH) - success', async () => {
    const response = await request(app.getHttpServer())
      .patch('/users/update')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ username: 'newusername' })
      .expect(200);

    expect(response.body.username).toBe('newusername');
  });

  it('/users/update (PATCH) - username already taken', async () => {
    // Create another user with the new username
    await prisma.user.create({
      data: {
        address: 'another-address',
        email: 'another@example.com',
        username: 'newusername',
      },
    });

    const response = await request(app.getHttpServer())
      .patch('/users/update')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ username: 'newusername' })
      .expect(409);

    expect(response.body.message).toBe('Unique constraint failed on: username');
  });

  it('/users/update (PATCH) - unauthorized', async () => {
    await request(app.getHttpServer())
      .patch('/users/update')
      .send({ username: 'newusername' })
      .expect(401);
  });
});
