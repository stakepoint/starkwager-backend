import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsPositive,
} from 'class-validator';

export class CreateWagerDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsString()
  @IsNotEmpty()
  categoryId: string;

  @IsNumber()
  @IsPositive()
  @IsNotEmpty()
  stakeAmount: number;

  @IsString()
  @IsOptional()
  createdById: string;

  @IsOptional()
  @IsString({ each: true }) // Ensures all elements in the array are strings
  tags?: string[];
}
