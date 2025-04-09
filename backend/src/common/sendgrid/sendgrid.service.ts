import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as sgMail from '@sendgrid/mail';

import { EmailOptions, EmailResult } from './sendgrid.interfaces';

@Injectable()
export class SendgridService {
  private readonly logger = new Logger(SendgridService.name);

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('SENDGRID_API_KEY');
    if (!apiKey) {
      this.logger.error('SendGrid API Key is not configured');
      throw new Error('SendGrid API Key is missing');
    }
    sgMail.setApiKey(apiKey);
  }

  private createBaseMessage(options: EmailOptions) {
    return {
      to: options.to,
      from: this.configService.get<string>('SEND_GRID_MAIL_FROM'),
      subject: options.subject,
      attachments: options.attachments,
    };
  }

  async sendTextEmail(options: EmailOptions): Promise<EmailResult> {
    try {
      const msg = {
        ...this.createBaseMessage(options),
        text: options.text,
      };

      await sgMail.send(msg);

      this.logger.log(`Text email sent successfully to ${msg.to}`, {
        subject: msg.subject,
      });

      return {
        success: true,
        messageId: this.generateMessageId(),
      };
    } catch (error) {
      return this.handleEmailError(error, 'text', options);
    }
  }

  async sendHtmlEmail(options: EmailOptions): Promise<EmailResult> {
    try {
      const msg = {
        ...this.createBaseMessage(options),
        html: options.html,
      };

      await sgMail.send(msg);

      this.logger.log(`HTML email sent successfully to ${msg.to}`, {
        subject: msg.subject,
      });

      return {
        success: true,
        messageId: this.generateMessageId(),
      };
    } catch (error) {
      return this.handleEmailError(error, 'html', options);
    }
  }

  private generateMessageId(): string {
    return `${Date.now()}-${Math.random().toString(36).substring(2, 15)}`;
  }

  private handleEmailError(
    error: any,
    type: 'text' | 'html',
    options: EmailOptions,
  ): EmailResult {
    let errorCode = 'UNKNOWN_ERROR';
    let errorMessage = 'Failed to send email';

    // Detailed error parsing
    if (error.response) {
      const { body } = error.response;
      errorCode = body?.errors?.[0]?.message || 'SENDGRID_ERROR';
      errorMessage = body?.errors?.[0]?.message || error.message;
    } else if (error.message) {
      errorMessage = error.message;
    }

    // Log detailed error
    this.logger.error(`Failed to send ${type} email`, {
      error: errorMessage,
      recipient: options.to,
      subject: options.subject,
      errorCode,
    });

    return {
      success: false,
      error: {
        code: errorCode,
        message: errorMessage,
      },
    };
  }

  validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}
