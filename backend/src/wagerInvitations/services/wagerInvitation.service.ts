import { PrismaService } from 'nestjs-prisma';
import { CreateWagerInvitationDto } from '../dtos/wagerInvitations.dto';
import { Injectable } from '@nestjs/common';

@Injectable()
export class WagerInvitationService {
  constructor(private prisma: PrismaService) {}

  async createInvitation(
    data: CreateWagerInvitationDto,
    invitedByUserId: string,
  ) {
    const invitation = await this.prisma.invitation.create({
      data: {
        wagerId: data.wagerId,
        invitedById: invitedByUserId,
        invitedUsername: data.invitedUsername,
        status: 'pending',
      },
    });
    return invitation;
  }

  async getInvitationsForWager(wagerId: string, invitedById: string) {
    const invitations = await this.prisma.invitation.findMany({
      where: { wagerId, invitedById },
      include: {
        invitedUser: true,
        wager: true,
      },
    });

    return invitations;
  }

  async findExistingInvitation(wagerId: string, invitedUsername: string) {
    const invitation = await this.prisma.invitation.findFirst({
      where: { wagerId, invitedUsername },
    });
    return invitation;
  }
}
