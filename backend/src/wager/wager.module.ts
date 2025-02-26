import { Global, Module } from '@nestjs/common';
import { WagerService } from './services/wager.service';
import { WagerController } from './controllers/wager.controller';
import { CategoryService } from '../category/services/category.service';

@Global()
@Module({
  controllers: [WagerController],
  providers: [WagerService, CategoryService],
  imports: [],
})
export class WagerModule {}
