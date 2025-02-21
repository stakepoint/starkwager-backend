import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsEnum,
  IsBoolean,
} from 'class-validator';

export enum NotificationType{
  WAGER_UPDATE = 'wager_update',
  INVITATION = 'invitation',
  GENERAL = 'general',
}


export class CreateNotificationDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsString()
  @IsNotEmpty()
  message: string;

  @IsBoolean()
  @IsNotEmpty()
  isRead?: boolean;

  @IsString()
  @IsNotEmpty()
  @IsEnum(NotificationType)
  @IsOptional()
  type: NotificationType;

}
