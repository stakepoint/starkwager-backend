import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateAuthDto } from './dto/create-auth.dto';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../common/metadata';

@ApiTags('Auth')
@Public()
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('create-login')
  create(@Body() createAuthDto: CreateAuthDto) {
    return this.authService.createOrLogin(createAuthDto);
  }
}
