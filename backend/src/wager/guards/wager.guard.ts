import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';
import { CategoryService } from 'src/category/services/category.service';
import { CreateWagerDto } from '../dtos/wager.dto';
import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';

@Injectable()
export class CreateWagerGuard implements CanActivate {
  constructor(private readonly categoryService: CategoryService) {}

  async canActivate(context: ExecutionContext) {
    const req: Request = context.switchToHttp().getRequest();

    // Convert the raw body to an instance of CreateWagerDto
    const dto = plainToInstance(CreateWagerDto, req.body);

    // Validate the DTO
    const errors = await validate(dto);
    if (errors.length > 0) {
      const formattedErrors = this.formatValidationErrors(errors);
      throw new BadRequestException(formattedErrors);
    }

    // Check if the category exists
    const isExists = await this.categoryService.findOne(dto.categoryId);
    if (!isExists) {
      throw new BadRequestException('Kindly enter a valid category');
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
