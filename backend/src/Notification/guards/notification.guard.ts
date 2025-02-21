import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';
import { CategoryService } from 'src/category/services/category.service';
import { CreateNotificationDto } from '../dtos/notification.dto';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { UsersService } from 'src/users/users.service';

@Injectable()
export class CreateNotificationGuard implements CanActivate {
  constructor(private readonly userService: UsersService) {}

  async canActivate(context: ExecutionContext) {
    const req: Request = context.switchToHttp().getRequest();

    // Convert the raw body to an instance of CreateNotificationDto
    const dto = plainToInstance(CreateNotificationDto, req.body);

    // Validate the DTO
    const errors = await validate(dto);
    if (errors.length > 0) {
      const formattedErrors = this.formatValidationErrors(errors);
      throw new BadRequestException(formattedErrors);
    }

    // Check if the category exists
    const isExists = await this.userService.findOne(dto.userId);
    if (!isExists) {
      throw new BadRequestException('Kindly enter a valid user');
    }

    // Attach the validated DTO to the request for later use
    req.body = dto;

    return true;
  }
  private formatValidationErrors(errors: any[]) {
    const messages = errors.flatMap((error) => {
      return Object.values(error.constraints);
    });

    return {
      message: messages,
      error: 'Bad Request',
      statusCode: 400,
    };
  }
}
