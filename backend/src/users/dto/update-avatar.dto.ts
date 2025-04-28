import { IsString } from 'class-validator';

export class UpdateAvatarDto {
  @IsString()
  picture: string;
}
