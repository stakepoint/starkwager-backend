import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ConflictException,
  Inject,
  Req,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { WagerInvitationService } from '../services/wagerInvitation.service';
import { CreateWagerInvitationDto } from '../dtos/wagerInvitations.dto';
import { CreateInvitationGuard } from '../guards/wagerInvitation.guard';
import { ConfigType } from '@nestjs/config';
import { AppConfig } from 'src/config';

@Controller('invitations')
export class WagerInvitationController {
  constructor(
    @Inject(AppConfig.KEY)
    private appConfig: ConfigType<typeof AppConfig>,
    private invitationService: WagerInvitationService,
    private jwtService: JwtService,
  ) {}

  @Post('create')
  @UseGuards(CreateInvitationGuard)
  async createInvitation(
    @Body() data: CreateWagerInvitationDto,
    @Req() req: Request,
  ) {
    const invitedByUserId = req['user'].sub;
    // Ensure user is not invited more than once to the same wager
    const existingInvitation =
      await this.invitationService.findExistingInvitation(
        data.wagerId,
        data.invitedUsername,
      );
    if (existingInvitation) {
      throw new ConflictException(
        'User has already been invited to this wager',
      );
    }
    const invitation = await this.invitationService.createInvitation(
      data,
      invitedByUserId,
    );

    // Generate JWT token for invitation
    const invitationToken = await this.jwtService.signAsync(
      { invitationId: invitation.id },
      {
        expiresIn: this.appConfig.invitationTokenExpiry,
        secret: this.appConfig.secret,
      },
    );

    return { invitation, invitationToken };
  }

  @Get('wager/:wagerId')
  async getInvitationsForWager(
    @Param('wagerId') wagerId: string,
    @Req() req: Request,
  ) {
    const userId = req['user'].sub;
    return await this.invitationService.getInvitationsForWager(wagerId, userId);
  }
}
