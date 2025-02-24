import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Req,
  Query,
  Patch,
  Delete,
} from '@nestjs/common';
import { NotificationService } from '../services/notification.service';
import { CreateNotificationDto } from '../dtos/notification.dto';
import { ApiBearerAuth } from '@nestjs/swagger';

@ApiBearerAuth('JWT-AUTH')
@Controller('notification')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post('create')
  create(@Body() data: CreateNotificationDto, @Req() req: Request) {
    const userId = req['user'].sub;
    return this.notificationService.createNotification(userId, { ...data });
  }

  @Get('all')
  findAll(
    @Req() req: Request,
    @Query('isRead') isRead?: boolean,
  ) {
    const userId = req['user'].sub;
    return this.notificationService.getNotifications(userId, isRead);
  }
  
 @Patch(':id/read')
  markAsRead(@Param('id') id: string) {
    return this.notificationService.markAsRead(id);
  }

  @Delete(':id')
  deleteNotification(@Param('id') id: string) {
    return this.notificationService.deleteNotification(id);
  }

  @Get(':id')
  getNotification(@Param('id') id: string,    @Req() req: Request,) {
    const userId = req['user'].sub;
    return this.notificationService.getANotification(id, userId);
  }

}
