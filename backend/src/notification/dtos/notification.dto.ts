import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsEnum,
  IsBoolean,
} from 'class-validator';
import { NotificationType } from '@prisma/client';

export class CreateNotificationDto {
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
