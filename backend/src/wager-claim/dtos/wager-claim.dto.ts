import { IsEnum, IsNotEmpty, IsString, IsUrl, IsUUID } from 'class-validator';
import { WagerClaimStatus } from '../../common/enums/status.enums';

export class CreateWagerClaimDto {
  @IsString()
  @IsUUID()
  @IsNotEmpty()
  wagerId: string;

  @IsString()
  @IsNotEmpty()
  @IsEnum(WagerClaimStatus)
  status: string;
}

export class RejectWagerClaimDto {
  @IsString()
  @IsUUID()
  @IsNotEmpty()
  id: string;

  @IsString()
  @IsNotEmpty()
  reason: string;

  @IsString()
  @IsNotEmpty()
  @IsEnum(WagerClaimStatus)
  status: string;

  @IsString()
  @IsUrl()
  proofLink: string;

  @IsString()
  @IsUrl()
  proofFile: string;
}
