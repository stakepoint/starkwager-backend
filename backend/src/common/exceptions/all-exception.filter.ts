import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpStatus,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { Prisma } from '@prisma/client';

@Catch(Prisma.PrismaClientKnownRequestError)
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(private readonly httpAdapterHost: HttpAdapterHost) {}

  catch(
    exception: Prisma.PrismaClientKnownRequestError,
    host: ArgumentsHost,
  ): void {
    const { httpAdapter } = this.httpAdapterHost;
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';

    switch (exception.code) {
      case 'P2002': {
        status = HttpStatus.CONFLICT;
        const target = exception.meta?.target as string[];
        message = `Unique constraint failed on: ${target.join(', ')}`;
        break;
      }
      case 'P2025': {
        status = HttpStatus.NOT_FOUND;
        message = 'Record not found';
        break;
      }
      case 'P2003': {
        status = HttpStatus.CONFLICT;
        message = 'Foreign key constraint failed';
        break;
      }
      case 'P2014': {
        status = HttpStatus.CONFLICT;
        message = 'Invalid relation data';
        break;
      }
      case 'P2021': {
        status = HttpStatus.INTERNAL_SERVER_ERROR;
        message = 'Table does not exist';
        break;
      }
      case 'P2022': {
        status = HttpStatus.INTERNAL_SERVER_ERROR;
        message = 'Column does not exist';
        break;
      }
    }

    const responseBody = {
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: httpAdapter.getRequestUrl(request),
      message,
      code: exception.code,
      meta: exception.meta,
    };

    httpAdapter.reply(response, responseBody, status);
  }
}
