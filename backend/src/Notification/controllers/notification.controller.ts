import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
  Query,
  Patch,
} from '@nestjs/common';
import { NotificationService } from '../services/notification.service';
import { CreateNotificationDto } from '../dtos/notification.dto';
import { CreateNotificationGuard } from '../guards/notification.guard';
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

@ApiBearerAuth('JWT-AUTH')
@Controller('notification')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('create')
  @UseGuards(CreateNotificationGuard)
  create(@Body() data: CreateNotificationDto, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.notificationService.createNotification({ ...data });
  }

    @Get(':userId/all')
    findAll(
      @Param('userId') userId: string,
      @Query('isRead') isRead: boolean
    ) {
      return this.notificationService.getNotifications(userId, isRead);
    }
  
 @Patch(':id/read')
  markAsRead(@Param('id') id: string) {
    return this.notificationService.markAsRead(id);
  }

}
