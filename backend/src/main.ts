import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const PORT = parseInt(process.env.PORT, 10) || 8080;

  const config = new DocumentBuilder()
    .setTitle('Starkwager backend')
    .setDescription('Backend for starkwager')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-AUTH',
    )
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('swagger/api', app, document);
  await app.listen(PORT, () => {
    console.log(`Running API in MODE: ${process.env.NODE_ENV} on port ${PORT}`);
  });
}
bootstrap();
