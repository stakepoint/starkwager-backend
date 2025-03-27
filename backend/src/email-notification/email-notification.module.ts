import { BullModule } from '@nestjs/bull';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { SendgridModule } from 'src/common/sendgrid/sendgrid.module';
import { EmailNotificationProcessor } from './email-notification.processor';
import { EMAIL_NOTIFICATION_QUEUE } from './email-notification.constants';
import { EmailNotificationService } from './email-notification.service';

@Module({
  imports: [
    ConfigModule,

    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        redis: {
          host: configService.get<string>('REDIS_HOST', 'localhost'),
          port: configService.get<number>('REDIS_PORT', 6379),
          password: configService.get<string>('REDIS_PASSWORD', ''),
        },
      }),
      inject: [ConfigService],
    }),

    // Register the specific queue
    BullModule.registerQueue({
      name: EMAIL_NOTIFICATION_QUEUE,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 1000,
        },
      },
      settings: {
        lockDuration: 30000,
        stalledInterval: 30000,
        maxStalledCount: 3,
      },
    }),

    SendgridModule,
  ],
  providers: [EmailNotificationProcessor, EmailNotificationService],
  exports: [BullModule, EmailNotificationService],
})
export class EmailNotificationModule {}
