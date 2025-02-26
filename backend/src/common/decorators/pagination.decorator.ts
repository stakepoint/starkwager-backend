import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  BadRequestException,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { Request } from 'express';
import { plainToInstance } from 'class-transformer';
import { validateOrReject } from 'class-validator';
import { PaginationQueryDto } from '../dtos/pagination.dto';

@Injectable()
export class PaginationInterceptor implements NestInterceptor {
  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest<Request>();
    const { page = 1, limit = 10 } = request.query;

    // Create a DTO instance for validation
    const paginationParams = plainToInstance(PaginationQueryDto, {
      page: +page,
      limit: +limit,
    });

    // Validate the DTO
    try {
      await validateOrReject(paginationParams);
    } catch (errors) {
      throw new BadRequestException(this.formatValidationErrors(errors));
    }
    request['pagination'] = { page: +page, limit: +limit };
    return next.handle();
  }

  private formatValidationErrors(errors: any[]): string {
    return errors
      .map((error) => Object.values(error.constraints).join(', '))
      .join('; ');
  }
}
