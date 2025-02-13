import { Global, Module } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { WagerService } from 'src/wager/services/wager.service';
import { WagerInvitationController } from './controllers/wagerInvitation.controller';
import { WagerInvitationService } from './services/wagerInvitation.service';
import { JwtModule } from '@nestjs/jwt';

@Global()
@Module({
  controllers: [WagerInvitationController],
  providers: [WagerInvitationService, UsersService, WagerService],
  imports: [JwtModule],
})
export class InvitationModule {}
