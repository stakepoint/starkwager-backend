import { Global, Module } from '@nestjs/common';
import { WagerService } from './services/wager.service';
import { WagerController } from './controllers/wager.controller';
import { CategoryService } from '../category/services/category.service';
import { JwtService } from '@nestjs/jwt';

@Global()
@Module({
  controllers: [WagerController],
  providers: [WagerService, CategoryService, JwtService],
  imports: [],
})
export class WagerModule {}
