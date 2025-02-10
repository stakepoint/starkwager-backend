import { IsString, IsNotEmpty, Matches } from 'class-validator';

export class CreateHashtagDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[a-zA-Z0-9_]+$/, {
    message: 'Hashtag name can only contain letters, numbers, and underscores',
  })
  name: string;
}
