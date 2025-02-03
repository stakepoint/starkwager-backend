import {
  BadRequestException,
  Injectable,
  NestMiddleware,
} from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { AuthService } from 'src/auth/auth.service';

@Injectable()
export class UserTokenMiddleware implements NestMiddleware {
  constructor(private readonly authService: AuthService) {}
  async use(req: Request, res: Response, next: NextFunction) {
    if (!req.headers.authorization) return next();
    const authorizationHeader = req.headers.authorization;
    const [bearer, token] = authorizationHeader.split(' ');
    if (bearer !== 'Bearer' || !token) {
      throw new BadRequestException('please provide a valid JWT token');
    }
    const tokenData = await this.authService.verifyUserToken(token);
    // token data is not valid
    if (!tokenData) {
      throw new BadRequestException('please provide a valid JWT token');
    }
    res.locals.tokenData = tokenData;
    next();
  }
}
