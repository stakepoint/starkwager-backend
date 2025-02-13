import { Global, Module } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { WagerService } from 'src/wager/services/wager.service';
import { WagerInvitationController } from './controllers/wagerInvitation.controller';
import { WagerInvitationService } from './services/wagerInvitation.service';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';

@Global()
@Module({
  controllers: [WagerInvitationController],
  providers: [WagerInvitationService, UsersService, WagerService],
  imports: [
    JwtModule.registerAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get('APP_CONFIG.secret'),
        signOptions: {
          expiresIn: configService.get('APP_CONFIG.accessTokenExpiry'),
        },
        global: true,
      }),
      inject: [ConfigService],
    }),
  ],
})
export class InvitationModule {}
