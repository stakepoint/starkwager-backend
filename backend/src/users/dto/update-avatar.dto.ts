import { IsUrl } from 'class-validator';

export class UpdateAvatarDto {
  @IsUrl({}, { message: 'Picture must be a valid URL' })
  picture: string;
}
