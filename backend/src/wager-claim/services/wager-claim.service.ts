import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import {
  CreateWagerClaimDto,
  RejectWagerClaimDto,
} from '../dtos/wager-claim.dto';
import { WagerClaimStatus, WagerStatus } from '../../common/enums/status.enums';

@Injectable()
export class WagerClaimService {
  constructor(private readonly prisma: PrismaService) {}

  async createClaim(dto: CreateWagerClaimDto, claimedById: string) {
    const { wagerId } = dto;

    const wager = await this.prisma.wager.findUnique({
      where: { id: wagerId },
    });

    if (!wager) {
      throw new BadRequestException('Wager not found');
    }

    if (wager.status !== WagerStatus.ACTIVE) {
      throw new BadRequestException('Only active wagers can be claimed');
    }

    const existingClaim = await this.prisma.wagerClaim.findUnique({
      where: { wagerId },
    });

    if (existingClaim) {
      throw new BadRequestException('This wager has already been claimed');
    }

    const claim = await this.prisma.wagerClaim.create({
      data: {
        wagerId,
        claimedById,
        status: WagerClaimStatus.PENDING,
      },
    });

    return claim;
  }

  async acceptClaim(claimId: string, userId: string) {
    const claim = await this.prisma.wagerClaim.findUnique({
      where: { id: claimId },
    });

    if (!claim) {
      throw new BadRequestException('Claim not found');
    }

    // Check so The user that create the claim can't accept it.
    if (claim.claimedById === userId) {
      throw new BadRequestException(
        'You are not authorized to accept this claim as you are the creator',
      );
    }

    //Todo: Make sure is only the other invited user that can accept this claim

    const wager = await this.prisma.wager.findUnique({
      where: { id: claim.wagerId },
    });

    if (!wager) {
      throw new BadRequestException('Wager not found');
    }

    if (wager.status !== WagerStatus.ACTIVE) {
      throw new BadRequestException('Only active wagers can be claimed');
    }

    await this.prisma.wager.update({
      where: { id: wager.id },
      data: {
        status: WagerStatus.COMPLETED,
      },
    });

    const updatedClaim = await this.prisma.wagerClaim.update({
      where: { id: claim.id },
      data: {
        status: WagerClaimStatus.ACCEPTED,
      },
    });

    return updatedClaim;
  }

  async rejectClaim(dto: RejectWagerClaimDto, userId: string) {
    const { id, reason, proofLink, proofFile } = dto;

    const wagerClaim = await this.prisma.wagerClaim.findUnique({
      where: { id },
    });

    if (!wagerClaim) {
      throw new BadRequestException('WagerClaim not found');
    }

    // Check so The user that create the claim can't reject it.
    if (wagerClaim.claimedById === userId) {
      throw new BadRequestException(
        'You are not authorized to reject this claim',
      );
    }

    //Todo: Make sure is only the other invited user that can accept this claim

    if (wagerClaim.status !== WagerClaimStatus.PENDING) {
      throw new BadRequestException('Only pending claims can be rejected');
    }

    const updatedWagerClaim = await this.prisma.wagerClaim.update({
      where: { id },
      data: {
        id,
        reason,
        status: WagerClaimStatus.REJECTED,
        proofLink,
        proofFile,
      },
    });

    return updatedWagerClaim;
  }
}
