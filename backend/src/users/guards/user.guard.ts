import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Response } from 'express';
import { UsersService } from '../users.service';
import { UserTokenDto } from 'src/auth/dto/token.dto';
import { Role } from 'src/common/enums/roles.enum';

@Injectable()
export class AdminTypeGuard implements CanActivate {
  constructor(private readonly usersService: UsersService) {}

  async canActivate(context: ExecutionContext) {
    try {
      const response: Response = context.switchToHttp().getResponse();
      const tokenData: UserTokenDto = response.locals.tokenData;
      const account = await this.usersService.findOne(tokenData.sub);
      if (!account || account.roles !== Role.Admin) {
        throw new UnauthorizedException(
          'you are not authorize to perform this account',
        );
      }
      return true;
    } catch (e) {
      throw new BadRequestException(e.message);
    }
  }
}
