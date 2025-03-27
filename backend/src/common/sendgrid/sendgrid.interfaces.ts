export interface EmailOptions {
  to: string | string[];
  from?: string;
  subject: string;
  text?: string;
  html?: string;
  attachments?: Array<{
    content: string;
    filename: string;
    type?: string;
    disposition?: string;
  }>;
  templateData?: Record<string, any>;
}

export interface EmailResult {
  success: boolean;
  messageId?: string;
  error?: {
    code?: string;
    message: string;
  };
}
