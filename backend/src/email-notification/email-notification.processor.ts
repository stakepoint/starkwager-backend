import { Process, Processor } from '@nestjs/bull';
import { Job } from 'bull';
import { SendgridService } from 'src/common/sendgrid/sendgrid.service';
import {
  EMAIL_NOTIFICATION_QUEUE,
  EMAIL_NOTIFICATION_QUEUE_JOBS,
} from './email-notification.constants';

@Processor(EMAIL_NOTIFICATION_QUEUE)
export class EmailNotificationProcessor {
  constructor(private readonly sendgridService: SendgridService) {}

  @Process(EMAIL_NOTIFICATION_QUEUE_JOBS.SEND_HTML_EMAIL)
  async processHtmlEmail(job: Job) {
    const { type, email } = job.data;

    try {
      const result = await this.sendgridService.sendHtmlEmail({
        to: email.to,
        from: email.from,
        subject: email.subject,
        html: email.content,
      });

      if (!result) {
        throw new Error(`Failed to send ${type} email`);
      }

      return result;
    } catch (error) {
      console.error('Email processing failed:', error);
    }
  }

  @Process(EMAIL_NOTIFICATION_QUEUE_JOBS.SEND_TEXT_EMAIL)
  async processTextEmail(job: Job) {
    const { type, email } = job.data;

    try {
      const result = await this.sendgridService.sendTextEmail({
        to: email.to,
        from: email.from,
        subject: email.subject,
        text: email.content,
      });

      if (!result) {
        throw new Error(`Failed to send ${type} email`);
      }

      return result;
    } catch (error) {
      console.error('Email processing failed:', error);
    }
  }
}
