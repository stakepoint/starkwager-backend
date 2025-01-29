import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersService } from 'src/users/users.service';
import { UsersModule } from 'src/users/users.module';
import { RpcProvider } from 'starknet';
import { JwtService } from '@nestjs/jwt';

@Module({
  imports: [UsersModule],
  controllers: [AuthController],
  providers: [AuthService, UsersService, RpcProvider, JwtService],
})
export class AuthModule {}
