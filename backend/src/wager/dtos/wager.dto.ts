import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsPositive,
  IsIn,
  IsEnum,
} from 'class-validator';

enum WagerStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  COMPLETED = 'completed',
}
export default WagerStatus;

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
  @IsEnum(WagerStatus)
  @IsOptional() 
  status?: string;

  @IsString()
  @IsOptional()
  createdById: string;

  @IsOptional()
  @IsString({ each: true }) // Ensures all elements in the array are strings
  tags?: string[];
}
