import { Body, Controller, Param, Patch, Post, Req } from '@nestjs/common';
import { WagerClaimService } from '../services/wager-claim.service';
import { CreateWagerClaimDto } from '../dtos/wager-claim.dto';
import { WagerClaim } from '@prisma/client';

@Controller('wager-claim')
export class WagerClaimController {
  constructor(private readonly wagerClaimService: WagerClaimService) {}

  @Post()
  async create(@Body() dto: CreateWagerClaimDto, @Req() req: Request) {
    const claimedById = req['user'].sub;
    return this.wagerClaimService.createClaim(dto, claimedById);
  }

  @Patch('accept/:id')
  async accept(@Param('id') id: string, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.wagerClaimService.acceptClaim(id, userId);
  }

  @Patch('reject')
  async reject(@Body() dto: WagerClaim, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.wagerClaimService.rejectClaim(dto, userId);
  }
}
