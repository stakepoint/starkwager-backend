import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  Injectable,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { CategoryService } from 'src/category/services/category.service';
import { CreateWagerDto } from '../dtos/wager.dto';
import { UserTokenDto } from 'src/auth/dto/token.dto';

@Injectable()
export class CreateWagerGuard implements CanActivate {
  constructor(private readonly categoryService: CategoryService) {}

  async canActivate(context: ExecutionContext) {
    try {
      const req: Request = context.switchToHttp().getRequest();
      const response: Response = context.switchToHttp().getResponse();
      const tokenData: UserTokenDto = response.locals.tokenData;
      const value: CreateWagerDto = req.body;
      if (!value || Object.keys(value).length === 0)
        throw new BadRequestException('please enter at least one information');
      //check if the createdById matches the authenticated user’s ID
      if (value.createdById !== tokenData.sub) {
        throw new BadRequestException(
          'you are not authorized to perform this action',
        );
      }
      //check if category exists
      const isExists = await this.categoryService.findOne(value.categoryId);

      if (!isExists) {
        throw new BadRequestException('kindly enter a value category');
      }
      return true;
    } catch (e) {
      throw new BadRequestException(e.message);
    }
  }
}
