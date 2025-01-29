import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, IsEmail } from 'class-validator';
import { WeierstrassSignatureType } from 'starknet';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  address: string;

  @IsOptional()
  @IsString()
  username?: string;

  @IsOptional()
  @IsEmail({}, { message: 'Invalid email address' })
  email?: string;

  @IsOptional()
  @IsString()
  picture?: string;

  @IsOptional()
  @IsString()
  signature?: WeierstrassSignatureType;

  @IsOptional()
  @IsString()
  signedData?: string;
}
