import { IsNotEmpty, IsString } from 'class-validator';

export class CreateWagerInvitationDto {
  @IsString()
  @IsNotEmpty()
  wagerId: string;

  @IsString()
  @IsNotEmpty()
  invitedUsername: string;
}
