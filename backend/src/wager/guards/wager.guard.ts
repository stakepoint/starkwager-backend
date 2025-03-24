import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  forwardRef,
  Inject,
  Injectable,
} from '@nestjs/common';
import { Request } from 'express';
import { CategoryService } from 'src/category/services/category.service';
import { BulkCreateWagerDto, CreateWagerDto } from '../dtos/wager.dto';
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

export class BulkCreateWagerGuard implements CanActivate {
  constructor(
    @Inject(forwardRef(() => CategoryService))
    private readonly categoryService: CategoryService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req: Request = context.switchToHttp().getRequest();
    const bulkDto = plainToInstance(BulkCreateWagerDto, req.body);

    // Validate BulkCreateWagerDto structure
    const validationErrors = await validate(bulkDto);
    if (validationErrors.length > 0) {
      throw new BadRequestException(
        this.formatValidationErrors(validationErrors),
      );
    }

    // Ensure wagers array is not empty
    if (!bulkDto.wagers || bulkDto.wagers.length === 0) {
      throw new BadRequestException({
        message: 'Payload must be a non-empty array of wagers.',
        error: 'Bad Request',
        statusCode: 400,
      });
    }

    // Validate each wager inside the array
    const errors = await this.validateWagers(bulkDto.wagers);
    if (errors.length > 0) {
      throw new BadRequestException(errors);
    }

    // Attach the validated DTO to the request
    req.body = bulkDto;

    return true;
  }

  private async validateWagers(wagers: any[]): Promise<any[]> {
    const errors: any[] = [];

    for (const wager of wagers) {
      const validationResult = await validate(wager);
      if (validationResult.length > 0) {
        errors.push(...this.formatValidationErrors(validationResult));
      }

      // Ensure category exists
      if (!this.categoryService) {
        throw new BadRequestException('CategoryService is not available.');
      }

      const categoryExists = await this.categoryService.findOne(
        wager.categoryId,
      );
      if (!categoryExists) {
        errors.push(`Category with ID ${wager.categoryId} does not exist.`);
      }
    }

    return errors;
  }

  private formatValidationErrors(errors: any[]) {
    return errors.map((error) => ({
      field: error.property,
      message: Object.values(error.constraints),
    }));
  }
}
