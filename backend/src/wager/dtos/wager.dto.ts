import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsPositive,
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

export class GetWagersQueryDto {
  @IsOptional()
  @IsEnum(WagerStatus, {
    message: `Invalid status. Valid values are: ${Object.values(WagerStatus).join(', ')}`,
  })
  status?: WagerStatus;

  @IsOptional()
  @IsString()
  hashtags?: string;

  @IsOptional()
  @IsString()
  filterType?: 'AND' | 'OR';
}
