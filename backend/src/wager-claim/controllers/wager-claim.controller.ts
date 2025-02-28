import { Body, Controller, Param, Patch, Post } from '@nestjs/common';
import { WagerClaimService } from '../services/wager-claim.service';
import { CreateWagerClaimDto } from '../dtos/wager-claim.dto';
import { WagerClaim } from '@prisma/client';

@Controller('wager-claim')
export class WagerClaimController {
  constructor(private readonly wagerClaimService: WagerClaimService) {}

  @Post()
  async create(@Body() dto: CreateWagerClaimDto) {
    return this.wagerClaimService.createClaim(dto);
  }

  @Patch('accept/:id')
  async accept(@Param('id') id: string) {
    return this.wagerClaimService.acceptClaim(id);
  }

  @Post('reject')
  async reject(@Body() dto: WagerClaim) {
    return this.wagerClaimService.rejectClaim(dto);
  }
}
