import {
  createParamDecorator,
  ExecutionContext,
  SetMetadata,
} from '@nestjs/common';
import { UserTokenDto } from '../dto/token.dto';
import { Response } from 'express';

export const UserTokenDecorator = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const response: Response = ctx.switchToHttp().getResponse();
    return response.locals.tokenData as UserTokenDto;
  },
);

export const UseToken = () => SetMetadata('token', true);
