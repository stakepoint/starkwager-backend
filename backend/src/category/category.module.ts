import { Global, Module } from '@nestjs/common';
import { CategoryService } from './services/category.service';
import { CategoryController } from './controllers/category.controller';
import { UsersService } from 'src/users/users.service';
@Global()
@Module({
  controllers: [CategoryController],
  providers: [CategoryService, UsersService],
  imports: [],
})
export class CategoryModule {}
