import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import {
  CreateWagerClaimDto,
  RejectWagerClaimDto,
} from '../dtos/wager-claim.dto';

@Injectable()
export class WagerClaimService {
  constructor(private readonly prisma: PrismaService) {}

  async createClaim(dto: CreateWagerClaimDto) {
    const { wagerId, claimedById, status } = dto;

    const wager = await this.prisma.wager.findUnique({
      where: { id: wagerId },
    });

    if (!wager) {
      throw new BadRequestException('Wager not found');
    }

    if (wager.status !== 'active') {
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
        status,
      },
    });

    return claim;
  }

  async acceptClaim(claimId: string) {
    const claim = await this.prisma.wagerClaim.findUnique({
      where: { id: claimId },
    });

    if (!claim) {
      throw new BadRequestException('Claim not found');
    }

    const wager = await this.prisma.wager.findUnique({
      where: { id: claim.wagerId },
    });

    if (!wager) {
      throw new BadRequestException('Wager not found');
    }

    if (wager.status !== 'active') {
      throw new BadRequestException('Only active wagers can be claimed');
    }

    await this.prisma.wager.update({
      where: { id: wager.id },
      data: {
        status: 'completed',
      },
    });

    const updatedClaim = await this.prisma.wagerClaim.update({
      where: { id: claim.id },
      data: {
        status: 'accepted',
      },
    });

    return updatedClaim;
  }

  async rejectClaim(dto: RejectWagerClaimDto) {
    const { wagerClaimId, reason, status, proofLink, proofFile } = dto;

    if (!proofLink && !proofFile) {
      throw new BadRequestException('Proof link or file is required');
    }

    if (proofLink && !this.isValidUrl(proofLink)) {
      throw new BadRequestException('Invalid proof link');
    }

    const wagerClaim = await this.prisma.wagerClaim.findUnique({
      where: { id: wagerClaimId },
    });

    if (!wagerClaim) {
      throw new BadRequestException('WagerClaim not found');
    }

    if (wagerClaim.status !== 'pending') {
      throw new BadRequestException('Only pending claims can be rejected');
    }

    const rejectWagerClaim = await this.prisma.rejectWagerClaim.create({
      data: {
        wagerClaimId,
        reason,
        status,
        proofLink,
        proofFile,
      },
    });

    await this.prisma.wagerClaim.update({
      where: { id: wagerClaim.id },
      data: {
        status: 'rejected',
      },
    });

    return rejectWagerClaim;
  }

  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
