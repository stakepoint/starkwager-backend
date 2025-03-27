import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import { SendgridService } from 'src/common/sendgrid/sendgrid.service';

@Injectable()
export class EmailNotificationService {
  private readonly logger = new Logger(EmailNotificationService.name);

  constructor(private readonly sendgridService: SendgridService) {}

  async sendOnboardingEmail(email: string): Promise<boolean> {
    try {
      const emailText = 'Test';

      const result = await this.sendgridService.sendTextEmail({
        to: email,
        subject: 'Welcome to Our Platform',
        text: emailText,
      });

      if (result.success) {
        this.logger.log(`Onboarding email sent to ${email}`, {
          messageId: result.messageId,
        });
        return true;
      } else {
        this.logger.error(`Failed to send onboarding email to ${email}`, {
          error: result.error,
        });
        return false;
      }
    } catch (error) {
      this.logger.error(
        `Unexpected error sending onboarding email to ${email}`,
        {
          error,
        },
      );
      return false;
    }
  }

  private getTemplate(
    templateName: string,
    folder: string,
    context: Record<string, any>,
  ): string {
    const filePath = join(
      __dirname,
      `../../../../templates/${folder}`,
      `${templateName}.html`,
    );
    let template = readFileSync(filePath, 'utf8');

    // Replace placeholders (e.g., {{ userName }})
    Object.keys(context).forEach((key) => {
      template = template.replace(
        new RegExp(`{{\\s*${key}\\s*}}`, 'g'),
        context[key],
      );
    });

    return template;
  }
}
