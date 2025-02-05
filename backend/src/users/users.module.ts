import { Global, Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';

@Global()
@Module({
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}
