import { Type } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  IsPositive,
  IsEnum,
  IsArray,
  ValidateNested,
} from 'class-validator';

enum WagerStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  COMPLETED = 'completed',
}

export enum TxStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  FAILED = 'failed',
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

  @IsString()
  txHash: string;

  @IsString()
  @IsEnum(TxStatus)
  txStatus: string;

  @IsOptional()
  @IsString({ each: true })
  hashtags?: string[];
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

export class BulkCreateWagerDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateWagerDto)
  wagers: CreateWagerDto[];
}
