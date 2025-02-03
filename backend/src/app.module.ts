import {
  Logger,
  MiddlewareConsumer,
  Module,
  NestModule,
  RequestMethod,
  ValidationPipe,
} from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { PrismaModule, loggingMiddleware } from 'nestjs-prisma';

import { AuthModule } from './auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { AppConfig } from './config';

import { AllExceptionsFilter } from './common/exceptions/all-exception.filter';
import { APP_FILTER, APP_PIPE } from '@nestjs/core';
import { CategoryModule } from './category/category.module';
import { WagerModule } from './wager/wager.module';
import { UserTokenMiddleware } from './common/middleware/auth.middleware';
import { AuthService } from './auth/auth.service';
import { UsersService } from './users/users.service';
import { JwtService } from '@nestjs/jwt';

@Module({
  imports: [
    UsersModule,
    AuthModule,
    CategoryModule,
    WagerModule,
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      load: [AppConfig],
    }),
    PrismaModule.forRoot({
      isGlobal: true,
      prismaServiceOptions: {
        middlewares: [
          // configure your prisma middleware
          loggingMiddleware({
            logger: new Logger('PrismaMiddleware'),
            logLevel: 'log',
          }),
        ],
      },
    }),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    AuthService,
    UsersService,
    JwtService,
    {
      provide: APP_PIPE,
      useValue: new ValidationPipe({ whitelist: true, transform: true }),
    },
    {
      provide: APP_FILTER,
      useClass: AllExceptionsFilter,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    return consumer.apply(UserTokenMiddleware).forRoutes({
      path: '*',
      method: RequestMethod.ALL,
    });
  }
}
