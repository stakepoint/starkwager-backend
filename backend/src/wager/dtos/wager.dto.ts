import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsPositive,
  IsIn,
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
  @IsNotEmpty()
  @IsIn(['pending', 'active', 'completed']) // Restrict allowed values
  @IsOptional() 
  status?: string;

  @IsString()
  @IsOptional()
  createdById: string;

  @IsOptional()
  @IsString({ each: true }) // Ensures all elements in the array are strings
  tags?: string[];
}
