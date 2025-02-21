import { IsNotEmpty, IsString, Length, Matches, IsUrl } from 'class-validator';

export class UpdateUsernameDto {
  @IsString()
  @IsNotEmpty()
  @Length(4, 20)
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'Username can only contain letters, numbers, and underscores',
  })
  username: string;

  @IsUrl({}, { message: 'Picture must be a valid URL' })
  picture: string;
}
