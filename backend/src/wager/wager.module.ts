import { Module } from '@nestjs/common';
import { WagerService } from './services/wager.service';
import { WagerController } from './controllers/wager.controller';

@Module({
  controllers: [WagerController],
  providers: [WagerService],
})
export class WagerModule {}
