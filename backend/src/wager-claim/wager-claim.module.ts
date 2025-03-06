import { Module } from '@nestjs/common';
import { WagerClaimService } from './services/wager-claim.service';
import { WagerClaimController } from './controllers/wager-claim.controller';

@Module({
  providers: [WagerClaimService],
  controllers: [WagerClaimController],
})
export class WagerClaimModule {}
